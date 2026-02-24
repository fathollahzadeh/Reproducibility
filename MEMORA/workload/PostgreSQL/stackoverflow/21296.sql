
WITH RankedPost AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2020-01-01' 
        AND p.Body IS NOT NULL 
        AND (p.Title IS NOT NULL OR p.Tags IS NOT NULL)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId, p.Score
),
FilteredPost AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPost rp
    WHERE 
        rp.RN = 1 
        AND (EXTRACT(DOW FROM rp.CreationDate) = 0 OR rp.ViewCount > 100) 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    COALESCE(fp.UpVotes - fp.DownVotes, 0) AS NetVotes, 
    CASE 
        WHEN fp.CommentCount = 0 THEN 'No Comments'
        WHEN fp.UpVotes >= 10 THEN 'Popular'
        ELSE 'Regular'
    END AS PostStatus,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    FilteredPost fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.WikiPostId = fp.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    NetVotes DESC, fp.ViewCount DESC
LIMIT 50;
