
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE(ph.RevisionGUID, 'None') AS LastRevisionGUID,
        COALESCE(ih.Text, 'No edits') AS LastEditText
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
        AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
    LEFT JOIN 
        PostHistory ih ON p.Id = ih.PostId
        AND ih.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id AND PostHistoryTypeId IN (4, 5, 6))
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, ph.RevisionGUID, ih.Text
),
VoteDetails AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CommentDetails AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        STRING_AGG(c.Text, ' | ' ORDER BY c.CreationDate) AS Comments
    FROM 
        Comments c
    GROUP BY 
        PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.Tags,
    vd.UpVotes,
    vd.DownVotes,
    vd.TotalVotes,
    cd.CommentCount,
    cd.Comments,
    pd.LastRevisionGUID,
    pd.LastEditText
FROM 
    PostDetails pd
LEFT JOIN 
    VoteDetails vd ON pd.PostId = vd.PostId
LEFT JOIN 
    CommentDetails cd ON pd.PostId = cd.PostId
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 100;
