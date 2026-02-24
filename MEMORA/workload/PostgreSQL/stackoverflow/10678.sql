WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pc.PostCount,
        pvc.VoteCount,
        pc.TotalScore,
        pc.TotalViews
    FROM Posts p
    JOIN UserPostCounts pc ON p.OwnerUserId = pc.UserId
    JOIN PostVoteCounts pvc ON p.Id = pvc.PostId
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.PostCount,
    pa.VoteCount,
    pa.TotalScore,
    pa.TotalViews
FROM PostAnalysis pa
ORDER BY pa.TotalScore DESC, pa.VoteCount DESC
LIMIT 100;