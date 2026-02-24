
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, 
        p.CommentCount, u.DisplayName, u.Reputation
),
UserContribution AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalPostScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.ViewCount,
    pe.Score,
    pe.AnswerCount,
    pe.CommentCount,
    pe.OwnerDisplayName,
    pe.OwnerReputation,
    pe.TotalComments,
    pe.TotalUpVotes,
    pe.TotalDownVotes,
    uc.UserId AS ContributorUserId,
    uc.DisplayName AS ContributorDisplayName,
    uc.TotalPosts,
    uc.TotalPostScore,
    uc.TotalBadges
FROM 
    PostEngagement pe
JOIN 
    UserContribution uc ON pe.OwnerDisplayName = uc.DisplayName
ORDER BY 
    pe.Score DESC, pe.ViewCount DESC
LIMIT 100;
