WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.Score > 0
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(v.BountyAmount) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        ua.UserId, 
        ua.DisplayName, 
        ua.PostsCreated, 
        ua.CommentsMade, 
        ua.TotalBountySpent,
        DENSE_RANK() OVER (ORDER BY ua.PostsCreated DESC, ua.CommentsMade DESC) AS UserRank
    FROM 
        UserActivity ua
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ta.UserId,
    ta.DisplayName AS TopUserName,
    ta.PostsCreated,
    ta.CommentsMade,
    ta.TotalBountySpent,
    rp.CreationDate
FROM 
    RankedPosts rp
JOIN 
    TopUsers ta ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ta.UserId)
WHERE 
    rp.Rank <= 10 AND 
    ta.UserRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, ta.TotalBountySpent DESC;