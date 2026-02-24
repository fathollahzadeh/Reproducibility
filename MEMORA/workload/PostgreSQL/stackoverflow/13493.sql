
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        pt.Name AS PostType,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    pd.PostId,
    pd.Title AS PostTitle,
    pd.CreationDate AS PostCreationDate,
    pd.Score AS PostScore,
    pd.ViewCount AS PostViewCount,
    pd.AnswerCount AS PostAnswerCount,
    pd.CommentCount AS PostCommentCount,
    pd.PostType
FROM 
    UserStatistics us
LEFT JOIN 
    PostDetails pd ON us.UserId = pd.OwnerUserId
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
