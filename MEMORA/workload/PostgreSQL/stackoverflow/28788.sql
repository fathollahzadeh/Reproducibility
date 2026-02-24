WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.Score,
        RANK() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.CommentCount,
        ua.UpvoteCount,
        ROW_NUMBER() OVER (ORDER BY ua.UpvoteCount DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.QuestionCount > 0
)

SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.OwnerDisplayName,
    r.Tags,
    r.Score,
    tu.DisplayName AS TopUser,
    tu.UpvoteCount,
    tu.CommentCount,
    tu.QuestionCount
FROM 
    RankedPosts r
JOIN 
    TopUsers tu ON r.OwnerUserId = tu.UserId
WHERE 
    r.PostRank = 1 
ORDER BY 
    r.Score DESC, tu.UpvoteCount DESC
LIMIT 50;