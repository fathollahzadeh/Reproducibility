
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        up.Reputation AS OwnerReputation,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
        LEFT JOIN Posts a ON p.Id = a.ParentId
        JOIN Users up ON p.OwnerUserId = up.Id
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, up.Reputation
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.LastActivityDate
),
DetailedPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerReputation,
        ra.CommentCount,
        ra.LastActivityDate,
        ra.LastEditDate,
        rp.TotalBounty,
        rp.AnswerCount,
        COALESCE(rp.TotalBounty, 0) + (CASE WHEN ra.LastActivityDate > CURRENT_TIMESTAMP - INTERVAL '6 months' THEN 1 ELSE 0 END) AS ActivityScore
    FROM 
        RankedPosts rp
        JOIN RecentActivity ra ON rp.PostId = ra.PostId
),
FilteredPosts AS (
    SELECT 
        dps.*,
        DENSE_RANK() OVER (ORDER BY ActivityScore DESC) AS ActivityRank
    FROM 
        DetailedPostStats dps
    WHERE 
        dps.OwnerReputation > 100 AND
        (dps.AnswerCount > 5 OR dps.TotalBounty > 0)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerReputation,
    fp.CommentCount,
    fp.LastActivityDate,
    fp.LastEditDate,
    fp.TotalBounty,
    fp.AnswerCount,
    fp.ActivityScore,
    fp.ActivityRank
FROM 
    FilteredPosts fp
WHERE 
    fp.ActivityRank <= 10
ORDER BY 
    fp.ActivityScore DESC;
