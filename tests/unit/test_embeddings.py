"""T011: Tests for embeddings wrapper in memory_server.embeddings.

Tests validate the EmbeddingService class which wraps FastEmbed for
generating 384-dimensional normalized vectors from text content.
These tests are marked @pytest.mark.slow since they load the ML model.
"""

from __future__ import annotations

import math

import pytest

from memory_server.embeddings import EmbeddingService

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def cosine_similarity(vec_a: list[float], vec_b: list[float]) -> float:
    """Compute cosine similarity between two vectors."""
    dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
    magnitude_a = math.sqrt(sum(a * a for a in vec_a))
    magnitude_b = math.sqrt(sum(b * b for b in vec_b))
    if magnitude_a == 0 or magnitude_b == 0:
        return 0.0
    return dot_product / (magnitude_a * magnitude_b)


def vector_magnitude(vec: list[float]) -> float:
    """Compute the L2 magnitude (norm) of a vector."""
    return math.sqrt(sum(x * x for x in vec))


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def embedding_service() -> EmbeddingService:
    """Create a shared EmbeddingService instance (model loaded once)."""
    return EmbeddingService()


# ---------------------------------------------------------------------------
# embed_text Tests
# ---------------------------------------------------------------------------


@pytest.mark.slow
class TestEmbedText:
    """Tests for the embed_text method."""

    def test_returns_list_of_floats(self, embedding_service: EmbeddingService) -> None:
        """embed_text returns a list of float values."""
        result = embedding_service.embed_text("Hello world")
        assert isinstance(result, list)
        assert all(isinstance(x, float) for x in result)

    def test_returns_384_dimensions(self, embedding_service: EmbeddingService) -> None:
        """embed_text returns exactly 384 dimensions (all-MiniLM-L6-v2)."""
        result = embedding_service.embed_text("Test embedding dimensions")
        assert len(result) == 384

    def test_vector_is_normalized(self, embedding_service: EmbeddingService) -> None:
        """Resulting vector has unit magnitude (L2 normalized)."""
        result = embedding_service.embed_text("Normalized vector test")
        magnitude = vector_magnitude(result)
        assert abs(magnitude - 1.0) < 1e-5, f"Expected magnitude ~1.0, got {magnitude}"

    def test_deterministic_output(self, embedding_service: EmbeddingService) -> None:
        """Same input text produces the same embedding vector."""
        text = "Deterministic embedding test"
        result1 = embedding_service.embed_text(text)
        result2 = embedding_service.embed_text(text)
        # Vectors should be identical (not just similar)
        for v1, v2 in zip(result1, result2):
            assert abs(v1 - v2) < 1e-7

    def test_different_texts_produce_different_vectors(
        self, embedding_service: EmbeddingService
    ) -> None:
        """Different input texts produce different embedding vectors."""
        vec1 = embedding_service.embed_text("Python programming language")
        vec2 = embedding_service.embed_text("Quantum physics experiments")
        # Vectors should differ
        differences = sum(1 for a, b in zip(vec1, vec2) if abs(a - b) > 1e-6)
        assert differences > 0

    def test_empty_string_still_embeds(self, embedding_service: EmbeddingService) -> None:
        """Empty string produces a valid 384-dim vector (model handles it)."""
        result = embedding_service.embed_text("")
        assert len(result) == 384
        assert all(isinstance(x, float) for x in result)

    def test_long_text_embeds(self, embedding_service: EmbeddingService) -> None:
        """Long text (beyond typical token limits) still produces 384-dim vector."""
        long_text = "word " * 2000  # ~2000 words
        result = embedding_service.embed_text(long_text)
        assert len(result) == 384


# ---------------------------------------------------------------------------
# embed_batch Tests
# ---------------------------------------------------------------------------


@pytest.mark.slow
class TestEmbedBatch:
    """Tests for the embed_batch method."""

    def test_returns_list_of_vectors(self, embedding_service: EmbeddingService) -> None:
        """embed_batch returns a list of embedding vectors."""
        texts = ["First text", "Second text", "Third text"]
        results = embedding_service.embed_batch(texts)
        assert isinstance(results, list)
        assert len(results) == 3

    def test_each_vector_has_384_dimensions(self, embedding_service: EmbeddingService) -> None:
        """Each vector in the batch result has exactly 384 dimensions."""
        texts = ["Alpha", "Beta", "Gamma"]
        results = embedding_service.embed_batch(texts)
        for vec in results:
            assert len(vec) == 384

    def test_each_vector_is_normalized(self, embedding_service: EmbeddingService) -> None:
        """Each vector in the batch result is L2 normalized."""
        texts = ["Normalize check one", "Normalize check two"]
        results = embedding_service.embed_batch(texts)
        for vec in results:
            magnitude = vector_magnitude(vec)
            assert abs(magnitude - 1.0) < 1e-5

    def test_batch_matches_individual(self, embedding_service: EmbeddingService) -> None:
        """Batch embedding produces same results as individual embed_text calls."""
        texts = ["Batch consistency test A", "Batch consistency test B"]
        batch_results = embedding_service.embed_batch(texts)
        individual_results = [embedding_service.embed_text(t) for t in texts]

        for batch_vec, individual_vec in zip(batch_results, individual_results):
            for b, i in zip(batch_vec, individual_vec):
                assert abs(b - i) < 1e-6

    def test_empty_batch(self, embedding_service: EmbeddingService) -> None:
        """Empty input list returns empty output list."""
        results = embedding_service.embed_batch([])
        assert results == []

    def test_single_item_batch(self, embedding_service: EmbeddingService) -> None:
        """Single-item batch works correctly."""
        results = embedding_service.embed_batch(["Solo text"])
        assert len(results) == 1
        assert len(results[0]) == 384


# ---------------------------------------------------------------------------
# Semantic Similarity Tests
# ---------------------------------------------------------------------------


@pytest.mark.slow
class TestSemanticSimilarity:
    """Tests for semantic similarity properties of embeddings."""

    def test_similar_texts_high_similarity(self, embedding_service: EmbeddingService) -> None:
        """Semantically similar texts produce cosine similarity > 0.5."""
        vec1 = embedding_service.embed_text("How to configure Python logging")
        vec2 = embedding_service.embed_text("Setting up logging in a Python application")
        similarity = cosine_similarity(vec1, vec2)
        assert similarity > 0.5, f"Expected similarity > 0.5, got {similarity}"

    def test_dissimilar_texts_lower_similarity(self, embedding_service: EmbeddingService) -> None:
        """Dissimilar texts produce lower cosine similarity than similar texts."""
        base = embedding_service.embed_text("Machine learning model training")
        similar = embedding_service.embed_text("Training neural networks with data")
        dissimilar = embedding_service.embed_text("Cooking Italian pasta recipes")

        sim_similar = cosine_similarity(base, similar)
        sim_dissimilar = cosine_similarity(base, dissimilar)
        assert sim_similar > sim_dissimilar, (
            f"Similar ({sim_similar}) should be > dissimilar ({sim_dissimilar})"
        )

    def test_identical_texts_similarity_one(self, embedding_service: EmbeddingService) -> None:
        """Identical texts produce cosine similarity of 1.0."""
        text = "Exact duplicate text for testing"
        vec1 = embedding_service.embed_text(text)
        vec2 = embedding_service.embed_text(text)
        similarity = cosine_similarity(vec1, vec2)
        assert abs(similarity - 1.0) < 1e-5

    def test_code_related_texts_similar(self, embedding_service: EmbeddingService) -> None:
        """Code-related texts about the same topic produce high similarity."""
        vec1 = embedding_service.embed_text("Use pytest fixtures for test setup and teardown")
        vec2 = embedding_service.embed_text(
            "pytest fixture functions provide reusable test dependencies"
        )
        similarity = cosine_similarity(vec1, vec2)
        assert similarity > 0.5, f"Expected similarity > 0.5, got {similarity}"
