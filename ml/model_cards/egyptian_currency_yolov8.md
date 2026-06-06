# Egyptian Currency YOLOv8 Model Card

## Source

- Repository: https://github.com/A7MEDELRAGGAL/Egyptian-Currency-System
- Local weights: `assets/models/egyptian_currency_yolov8.pt`
- Labels: `assets/models/egyptian_currency_labels.json`
- Architecture: YOLOv8 detector
- Input size: 640x640

## Task

Detect Egyptian banknotes and map front/back classes to EGP values so the
assistant can count visible currency for blind users.

## Classes

| ID | Label | Value | Side |
| --- | --- | ---: | --- |
| 0 | 5_F | 5 EGP | Front |
| 1 | 5_B | 5 EGP | Back |
| 2 | 10_F | 10 EGP | Front |
| 3 | 10_B | 10 EGP | Back |
| 4 | 20_F | 20 EGP | Front |
| 5 | 20_B | 20 EGP | Back |
| 6 | 50_F | 50 EGP | Front |
| 7 | 50_B | 50 EGP | Back |
| 8 | 100_F | 100 EGP | Front |
| 9 | 100_B | 100 EGP | Back |
| 10 | 200_F | 200 EGP | Front |
| 11 | 200_B | 200 EGP | Back |

## Reported Evaluation

The upstream project reports:

- Precision: 99.89%
- Recall: 100%
- mAP50: 99.5%
- mAP50-95: 99.07%

## Mobile Integration Notes

The checked-in upstream model is a PyTorch `.pt` file. Flutter on-device
inference should use an exported `.tflite` model, so the next implementation
step is to export this model with Ultralytics:

```bash
yolo export model=assets/models/egyptian_currency_yolov8.pt format=tflite imgsz=640 nms=True
```

After export, place the generated model at:

```text
assets/models/egyptian_currency_yolov8.tflite
```

Then add a TFLite detector service that returns detections, class labels,
confidence, bounding boxes, and the summed EGP amount.
