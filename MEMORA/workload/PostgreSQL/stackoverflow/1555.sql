
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN pr.Name END) AS CloseReason,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes pr ON CAST(ph.Comment AS INTEGER) = pr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    cr.CloseReason,
    mu.DisplayName AS ActiveUser,
    mu.PostCount,
    mu.UpVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.Id = cr.PostId
RIGHT JOIN 
    MostActiveUsers mu ON rp.OwnerUserId = mu.UserId
WHERE 
    (cr.LastClosed IS NULL OR cr.LastClosed >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    AND mu.PostCount > 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
