WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        COUNT(c.Id) FILTER (WHERE c.PostId IS NOT NULL) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.PostId IS NOT NULL AND v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.PostId IS NOT NULL AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
        AND p.ViewCount > 100 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerDisplayName, p.Tags, p.ViewCount
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.ViewCount,
        rp.PostRank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1  
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.PopularityRank,
    COALESCE(CAST(SUBSTRING(p.Tags FROM '([^<]*)') AS varchar(30)), 'No Tags') AS MainTag,
    CASE 
        WHEN p.DownVoteCount > p.UpVoteCount THEN 'More Downvotes'
        WHEN p.UpVoteCount > p.DownVoteCount THEN 'More Upvotes'
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM 
    PopularPosts p
WHERE 
    p.PopularityRank <= 10 
ORDER BY 
    p.PopularityRank;