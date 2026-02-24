
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),

AggregatedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        (ph.CreationDate >= (SELECT MIN(PH2.CreationDate) FROM PostHistory PH2 WHERE PH2.PostHistoryTypeId = 10 AND PH2.PostId = ph.PostId)) AS IsClosed
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rd.TotalBounty,
        ph.Title AS ClosedPostTitle
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AggregatedData rd ON rd.UserId IN (
            SELECT UserId 
            FROM Posts 
            WHERE Id = rp.AcceptedAnswerId
            AND AcceptedAnswerId IS NOT NULL
        )
    LEFT JOIN 
        PostHistoryInfo ph ON ph.PostId = rp.PostId AND ph.IsClosed
    WHERE 
        rp.rn <= 5 
)

SELECT 
    fr.PostId,
    fr.Title,
    COALESCE(fr.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN fr.ClosedPostTitle IS NOT NULL THEN 'Closed: ' || fr.ClosedPostTitle 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.TotalBounty DESC, fr.PostId ASC;
