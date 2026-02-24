
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
RecentComments AS (
    SELECT 
        c.UserId, 
        c.PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments c 
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        c.UserId, c.PostId
),
DetailedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.AnswerCount, 
        tu.DisplayName AS TopUser,
        COALESCE(rc.CommentCount, 0) AS RecentCommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
    LEFT JOIN 
        RecentComments rc ON rp.PostId = rc.PostId
    WHERE 
        rp.PostRank <= 3
)
SELECT 
    dp.PostId, 
    dp.Title, 
    dp.CreationDate, 
    dp.Score, 
    dp.ViewCount, 
    dp.AnswerCount, 
    dp.TopUser,
    CASE 
        WHEN dp.RecentCommentCount > 0 THEN 'Has Recent Comments' 
        ELSE 'No Recent Comments' 
    END AS CommentStatus
FROM 
    DetailedPosts dp
ORDER BY 
    dp.Score DESC, dp.ViewCount DESC;
