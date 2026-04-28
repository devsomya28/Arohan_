from fastapi import APIRouter, HTTPException
from ..services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["Audit & Analytics"])
report_service = ReportService()

@router.get("/{incident_id}")
async def get_incident_report(incident_id: str):
    """
    Generate and retrieve a professional audit report for a specific incident.
    """
    report = await report_service.generate_incident_report(incident_id)
    if "error" in report:
        raise HTTPException(status_code=404, detail=report["error"])
    return report
