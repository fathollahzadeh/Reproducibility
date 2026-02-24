WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vote_counts.UpVotes, 0) AS UpVotes,
        COALESCE(vote_counts.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes v
        JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY 
            PostId
    ) AS vote_counts ON p.Id = vote_counts.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
PopularTags AS (
    SELECT 
        tg.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags tg
    JOIN 
        Posts p ON p.Tags LIKE '%' || tg.TagName || '%'
    GROUP BY 
        tg.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate,
    tp.ViewCount AS TopPostViews,
    tp.UpVotes AS TopPostUpVotes,
    tp.DownVotes AS TopPostDownVotes,
    pt.TagName AS PopularTag,
    pt.PostCount AS TagPostCount
FROM 
    TopPosts tp
JOIN 
    PopularTags pt ON tp.UpVotes > pt.PostCount
ORDER BY 
    tp.ViewCount DESC, tp.UpVotes DESC
LIMIT 10;
