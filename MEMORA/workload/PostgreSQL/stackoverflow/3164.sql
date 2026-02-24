
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        MAX(u.LastAccessDate) AS LastAccess
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.PostCount,
    up.TotalBadges,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    pc.LastCommentDate,
    CASE  
        WHEN rp.AcceptedAnswerId = 0 THEN 'No Accepted Answer'
        ELSE 'Has Accepted Answer'
    END AS AnswerStatus
FROM 
    UserStats up
    INNER JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
    LEFT JOIN PostComments pc ON rp.PostId = pc.PostId
WHERE 
    up.Reputation > 1000
    AND rp.rn <= 5
ORDER BY 
    up.Reputation DESC,
    rp.ViewCount DESC;
