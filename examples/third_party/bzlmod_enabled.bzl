"""detect whether bzlmod is enabled"""

BZLMOD_ENABLED = "@@" in str(Label("//:unused"))
