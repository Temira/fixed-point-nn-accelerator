from pathlib import Path


def parse_mem_file(path: Path, width: int = 16) -> list[int]:
    values: list[int] = []
    sign_bit = 1 << (width - 1)
    full_scale = 1 << width

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line:
            continue

        value = int(line, 16)
        if value & sign_bit:
            value -= full_scale
        values.append(value)

    return values


def post_process(acc: int, bias: int, out_w: int = 16, enabled: bool = True) -> int:
    if not enabled:
        return 0

    total = max(0, acc + bias)
    max_pos = (1 << (out_w - 1)) - 1
    return min(total, max_pos)


def dense_layer_reference(
    x: list[int],
    weights: list[int],
    biases: list[int],
    n_inputs: int,
) -> list[int]:
    outputs: list[int] = []

    for out_idx, bias in enumerate(biases):
        row = weights[out_idx * n_inputs:(out_idx + 1) * n_inputs]
        if len(row) != len(x):
            raise ValueError("Weight row length does not match input vector length")
        acc = sum(w * sample for w, sample in zip(row, x))
        outputs.append(post_process(acc, bias))

    return outputs


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    weights = parse_mem_file(root / "tb" / "test_vectors" / "weights.mem")
    biases = parse_mem_file(root / "tb" / "test_vectors" / "biases.mem")
    x = [3, -2, 1, 4]

    outputs = dense_layer_reference(x=x, weights=weights, biases=biases, n_inputs=4)

    print(f"input={x}")
    print(f"weights={weights}")
    print(f"biases={biases}")
    print(f"outputs={outputs}")


if __name__ == "__main__":
    main()
