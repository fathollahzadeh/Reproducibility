
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON true
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ActivityDate,
        pht.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
PostStatistics AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.Tags,
        pd.CommentCount,
        pd.VoteCount,
        (SELECT COUNT(*) FROM PostActivity pa WHERE pa.PostId = pd.PostId) AS ActivityCount
    FROM 
        PostDetails pd
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Tags,
    ps.CommentCount,
    ps.VoteCount,
    ps.ActivityCount,
    CASE 
        WHEN ps.ActivityCount > 5 THEN 'Highly Active'
        WHEN ps.ActivityCount BETWEEN 1 AND 5 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS ActivityLevel
FROM 
    PostStatistics ps
WHERE 
    ps.CommentCount > 0
ORDER BY 
    ps.VoteCount DESC, 
    ps.CommentCount DESC;
