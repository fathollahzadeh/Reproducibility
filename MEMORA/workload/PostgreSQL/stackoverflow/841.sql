
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        pv.UpVotes,
        pv.DownVotes,
        (pv.UpVotes - pv.DownVotes) AS NetVotes,
        CASE 
            WHEN pv.UpVotes >= pv.DownVotes THEN 'Positive' 
            ELSE 'Negative' 
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
)
SELECT 
    pa.Title,
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.NetVotes,
    pa.VoteSentiment,
    COUNT(DISTINCT c.Id) AS CommentCount,
    MAX(b.Class) AS HighestBadgeClass,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM 
    PostAnalytics pa
LEFT JOIN 
    Comments c ON pa.PostId = c.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pa.PostId LIMIT 1)
LEFT JOIN 
    PostLinks pl ON pa.PostId = pl.PostId
WHERE 
    pa.NetVotes > 0
GROUP BY 
    pa.Title, pa.OwnerDisplayName, pa.CreationDate, pa.Score, pa.ViewCount, pa.UpVotes, pa.DownVotes, pa.NetVotes, pa.VoteSentiment
HAVING 
    COUNT(DISTINCT c.Id) > 5 
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;
