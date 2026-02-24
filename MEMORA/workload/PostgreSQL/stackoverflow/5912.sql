
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Unaccepted' 
        END AS AnswerStatus,
        p.OwnerUserId
    FROM 
        Posts p
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.AnswerCount,
    ua.Upvotes,
    ua.Downvotes,
    ua.Reputation,
    ua.CreationDate,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount AS PostAnswerCount,
    ps.CommentCount,
    ps.Score,
    ps.AnswerStatus
FROM 
    UserActivity ua
JOIN 
    PostSummary ps ON ua.UserId = ps.OwnerUserId
WHERE 
    ua.ReputationRank <= 100 
ORDER BY 
    ua.Reputation DESC, 
    ps.ViewCount DESC;
