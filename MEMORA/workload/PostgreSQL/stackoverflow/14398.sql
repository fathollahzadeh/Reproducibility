
WITH PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.Tags,
        p.AcceptedAnswerId,
        COALESCE(vs.VoteCount, 0) AS VoteCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.CloseVotes, 0) AS CloseVotes,
        p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostVoteSummary vs ON p.Id = vs.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.LastActivityDate,
    pd.Tags,
    pd.VoteCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CloseVotes,
    CASE 
        WHEN pd.PostTypeId = 1 THEN 'Question'
        WHEN pd.PostTypeId = 2 THEN 'Answer'
        WHEN pd.PostTypeId = 3 THEN 'Wiki'
        ELSE 'Other'
    END AS PostType
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC
LIMIT 100;
