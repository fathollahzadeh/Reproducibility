WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        pt.Name AS PostTypeName,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS IsAcceptedAnswer
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
),
VotesSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 4 THEN 1 END) AS OffensiveVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.PostCreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.PostTypeName,
    pd.IsAcceptedAnswer,
    vs.UpVotes,
    vs.DownVotes,
    vs.OffensiveVotes
FROM 
    PostDetails pd
LEFT JOIN 
    VotesSummary vs ON pd.PostId = vs.PostId
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;