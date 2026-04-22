def relu_postprocess(acc: int, bias: int, out_w: int = 16, enabled: bool = True) -> int:
    if not enabled:
        return 0

    total = acc + bias
    total = max(0, total)

    max_pos = (1 << (out_w - 1)) - 1
    if total > max_pos:
        return max_pos
    return total


def main():
    tests = [
        (10, 3, 16, True),
        (10, -4, 16, True),
        (-8, 3, 16, True),
        (0, 0, 16, True),
        (40000, 0, 16, True),
        (100, 5, 16, False),
    ]

    for t in tests:
        acc, bias, out_w, enabled = t
        y = relu_postprocess(acc, bias, out_w, enabled)
        print(f"acc={acc}, bias={bias}, enabled={enabled} -> y={y}")


if __name__ == "__main__":
    main()
