"""T016: Embeddings wrapper for generating vector representations of text.

Wraps FastEmbed's TextEmbedding model to produce 384-dimensional L2-normalized
vectors suitable for semantic similarity search via sqlite-vec.
"""

from __future__ import annotations

from fastembed import TextEmbedding


class EmbeddingService:
    """Wrapper around FastEmbed TextEmbedding for generating text embeddings.

    Produces 384-dimensional L2-normalized float32 vectors using the
    BAAI/bge-small-en-v1.5 model by default.

    Example:
        >>> service = EmbeddingService()
        >>> vec = service.embed_text("Hello world")
        >>> len(vec)
        384
    """

    def __init__(self, model_name: str = "BAAI/bge-small-en-v1.5") -> None:
        """Initialize the embedding service with the specified model.

        Args:
            model_name: The FastEmbed model identifier. Defaults to
                BAAI/bge-small-en-v1.5 which produces 384-dim vectors.
        """
        self._model = TextEmbedding(model_name=model_name)

    def embed_text(self, text: str) -> list[float]:
        """Generate a 384-dimensional embedding vector for a single text.

        The resulting vector is L2-normalized (unit length).

        Args:
            text: The input text to embed. Empty strings produce a valid vector.

        Returns:
            A list of 384 float values representing the text embedding.
        """
        # TextEmbedding.embed() returns a generator of numpy arrays
        embeddings = list(self._model.embed([text]))
        return embeddings[0].tolist()  # type: ignore[no-any-return]

    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Generate embeddings for multiple texts efficiently.

        Processes all texts in a single batch for better throughput compared
        to calling embed_text repeatedly.

        Args:
            texts: A list of input texts to embed. An empty list returns
                an empty result.

        Returns:
            A list of embedding vectors, one per input text. Each vector
            is a 384-dimensional L2-normalized list of floats.
        """
        if not texts:
            return []

        embeddings = list(self._model.embed(texts))
        return [vec.tolist() for vec in embeddings]
