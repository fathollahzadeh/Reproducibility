
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '<>')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
),
VoteSummary AS (
    SELECT 
        PostId, 
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
BadgeSummary AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.OwnerDisplayName,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        pd.Tags,
        bd.BadgeCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        VoteSummary vs ON pd.PostId = vs.PostId
    LEFT JOIN 
        BadgeSummary bd ON pd.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bd.UserId)
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    UpVotes,
    DownVotes,
    Tags,
    BadgeCount
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;
