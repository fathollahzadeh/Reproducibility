WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        pt.Name AS PostType,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        RANK() OVER (PARTITION BY pt.Name ORDER BY COUNT(a.Id) DESC, COUNT(c.Id) DESC) AS RankByEngagement
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '365 days' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, pt.Name
),
TopEngagedPosts AS (
    SELECT 
        PostId, Title, Body, CreationDate, PostType, AnswerCount, CommentCount, TotalBounties
    FROM 
        RankedPosts
    WHERE 
        RankByEngagement <= 5
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tep.Title,
    tep.PostType,
    tep.AnswerCount,
    tep.CommentCount,
    tep.TotalBounties,
    ue.DisplayName AS EngagingUser,
    ue.TotalComments AS UserCommentCount,
    ue.TotalBounties AS UserTotalBounties
FROM 
    TopEngagedPosts tep
JOIN 
    UserEngagement ue ON ue.TotalComments > 0 OR ue.TotalBounties > 0
ORDER BY 
    tep.TotalBounties DESC, tep.AnswerCount DESC, tep.CommentCount DESC;