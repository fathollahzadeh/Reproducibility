WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(a.OwnerDisplayName, 'Community User') AS OwnerDisplayName,
        p.Score,
        pc.TagCount,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Comments c 
             WHERE c.PostId = p.Id), 0
        ) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        PostTagCounts pc ON p.Id = pc.PostId
    WHERE 
        p.PostTypeId = 1 
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.Score,
    pd.TagCount,
    pd.CommentCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.CloseVotes, 0) AS CloseVotes
FROM 
    PostDetails pd
LEFT JOIN 
    VoteStats vs ON pd.Id = vs.PostId
ORDER BY 
    pd.Score DESC,
    pd.TagCount DESC,
    pd.CommentCount DESC;