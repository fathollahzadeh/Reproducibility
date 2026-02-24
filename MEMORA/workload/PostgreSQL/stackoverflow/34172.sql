
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.Tags,
        COALESCE(pvs.Upvotes, 0) AS Upvotes,
        COALESCE(pvs.Downvotes, 0) AS Downvotes,
        COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Tags,
    tp.Upvotes,
    tp.Downvotes,
    tp.TotalVotes,
    CASE 
        WHEN tp.Upvotes > 0 THEN ROUND(tp.Upvotes::decimal / NULLIF(tp.TotalVotes, 0), 2)
        ELSE 0
    END AS UpvoteRatio,
    CASE 
        WHEN tp.Rank <= 10 THEN 'Top 10 Post'
        ELSE 'Other'
    END AS PostRanking
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10 OR (tp.Upvotes - tp.Downvotes) > 5
ORDER BY 
    tp.Rank;
