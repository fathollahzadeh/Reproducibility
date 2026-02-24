WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        p.OwnerUserId,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS TotalVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAcceptedAnswer
    FROM 
        Posts p
),
CommentStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.FavoriteCount,
        pd.TotalVotes,
        pd.IsAcceptedAnswer,
        ur.DisplayName,
        ur.ReputationRank
    FROM 
        PostDetails pd
    JOIN 
        UserReputation ur ON pd.OwnerUserId = ur.UserId
    WHERE 
        pd.ViewCount > 100 AND 
        pd.AnswerCount > 0
    ORDER BY 
        pd.ViewCount DESC
    LIMIT 10
)

SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    tp.TotalVotes,
    tp.IsAcceptedAnswer,
    COALESCE(cs.TotalComments, 0) AS TotalComments,
    tp.DisplayName AS UserDisplayName,
    tp.ReputationRank
FROM 
    TopPosts tp
LEFT JOIN 
    CommentStatistics cs ON tp.PostId = cs.PostId
ORDER BY 
    tp.ReputationRank, tp.ViewCount DESC;
