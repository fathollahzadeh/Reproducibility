WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVotes,
        COALESCE(pt.Name, 'Unknown Type') AS PostType
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.PostType
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 5 
),
PostWithComments AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.UpVotes,
        fp.DownVotes,
        fp.PostType,
        COUNT(c.Id) AS CommentCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.UpVotes, fp.DownVotes, fp.PostType
),
AggregateData AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.CreationDate,
        pwc.Score,
        pwc.UpVotes,
        pwc.DownVotes,
        pwc.CommentCount,
        CASE 
            WHEN pwc.Score > 0 THEN 'Positive'
            WHEN pwc.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory,
        RANK() OVER (ORDER BY pwc.UpVotes DESC, pwc.CommentCount DESC) AS PopularityRank
    FROM 
        PostWithComments pwc
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.CreationDate,
    ad.Score,
    ad.UpVotes,
    ad.DownVotes,
    ad.CommentCount,
    ad.ScoreCategory,
    ad.PopularityRank,
    mh.Date AS LastModified
FROM 
    AggregateData ad
LEFT JOIN 
    PostHistory ph ON ad.PostId = ph.PostId
LEFT JOIN 
    (SELECT 
         PostId, MAX(CreationDate) AS Date 
     FROM 
         PostHistory 
     WHERE 
         PostHistoryTypeId IN (4, 5, 6)
     GROUP BY 
         PostId) mh ON mh.PostId = ad.PostId
WHERE 
    ad.PopularityRank <= 10 
ORDER BY 
    ad.PopularityRank,
    ad.CreationDate DESC;