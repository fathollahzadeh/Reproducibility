WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        pht.Name AS PostHistoryTypeName,
        ph.Comment,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId 
        AND ph.CreationDate = (SELECT MAX(CreationDate) 
                               FROM PostHistory 
                               WHERE PostId = rp.PostId)
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.Rank <= 5  
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, u.DisplayName, pht.Name, ph.Comment
),
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        PostHistoryTypeName,
        CommentCount,
        UpVotes,
        DownVotes,
        CASE 
            WHEN UpVotes = 0 AND DownVotes = 0 THEN 'No Votes'
            WHEN UpVotes > DownVotes THEN 'Positive'
            WHEN UpVotes < DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        TopPosts
)
SELECT 
    pm.*,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON p.Id = pm.PostId 
     WHERE t.ExcerptPostId = p.Id) AS Tags
FROM 
    PostMetrics pm
WHERE 
    pm.CommentCount > 0
ORDER BY 
    Score DESC, CreationDate DESC;