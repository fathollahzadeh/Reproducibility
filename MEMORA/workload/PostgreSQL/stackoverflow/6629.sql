
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        PostStats
),
UserTopPosts AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        tp.Title,
        tp.ViewCount,
        tp.AnswerCount,
        tp.Upvotes,
        tp.Downvotes,
        ROW_NUMBER() OVER (PARTITION BY ue.UserId ORDER BY tp.ViewCount DESC) AS UserPostRank
    FROM 
        UserEngagement ue
    JOIN 
        Posts p ON ue.UserId = p.OwnerUserId
    JOIN 
        TopPosts tp ON p.Id = tp.PostId
)
SELECT 
    utp.DisplayName,
    utp.Title,
    utp.ViewCount,
    utp.AnswerCount,
    utp.Upvotes,
    utp.Downvotes
FROM 
    UserTopPosts utp
WHERE 
    utp.UserPostRank <= 5
ORDER BY 
    utp.DisplayName, utp.ViewCount DESC;
