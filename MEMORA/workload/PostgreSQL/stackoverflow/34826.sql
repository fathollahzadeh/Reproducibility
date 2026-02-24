WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId, 
        ph.UserId AS EditorUserId, 
        ph.CreationDate, 
        ph.Comment, 
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.LastEditDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount, 
        COALESCE(
            (SELECT 
                MAX(vote.CreationDate) 
            FROM 
                Votes vote 
            WHERE 
                vote.PostId = p.Id AND vote.VoteTypeId = 3), 
            NULL
        ) AS LatestDownVoteDate,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastEditDate, p.Score, p.ViewCount, p.OwnerUserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.PostCreationDate,
    pd.LastEditDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    rph.EditorUserId,
    rph.Comment AS EditorComment,
    rph.Text AS EditText,
    pd.LatestDownVoteDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    PostDetails pd
LEFT JOIN 
    RecursivePostHistory rph ON pd.PostId = rph.PostId AND rph.RecentEdit = 1
JOIN 
    Users u ON pd.OwnerUserId = u.Id
WHERE 
    pd.Score > 5
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC
LIMIT 100;