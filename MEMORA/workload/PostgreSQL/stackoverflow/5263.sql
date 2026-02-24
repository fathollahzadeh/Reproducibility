
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.OwnerUserId
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    CASE 
        WHEN pp.UpVotes > pp.DownVotes THEN 'Positive'
        WHEN pp.UpVotes < pp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PopularPosts pp
ORDER BY 
    pp.PopularityRank;
