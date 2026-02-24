
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        SUM(v.BountyAmount) AS TotalBounties,
        COALESCE(NULLIF(AVG(u.Reputation), 0), 1) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId, p.Score
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.CommentCount,
    RP.Rank,
    RP.TotalBounties,
    RP.AvgUserReputation,
    PH.Comment,
    PH.CreationDate AS HistoryCreationDate,
    CASE 
        WHEN RP.CommentCount > 10 THEN 'Highly Engaged'
        WHEN RP.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    RankedPosts RP
LEFT JOIN 
    (SELECT DISTINCT p.Id, ph.Comment, ph.CreationDate
     FROM Posts p
     JOIN PostHistory ph ON p.Id = ph.PostId
     WHERE ph.PostHistoryTypeId IN (10, 11, 12)   
     AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months') PH ON RP.PostId = PH.Id
WHERE 
    RP.Rank <= 3 
    OR RP.TotalBounties > 0 
ORDER BY 
    RP.AvgUserReputation DESC, 
    RP.ViewCount DESC
LIMIT 50;
