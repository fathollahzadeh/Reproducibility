
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        REPLACE(REPLACE(p.Tags, '<', ''), '>', '') AS CleanedTags,
        pt.Name AS PostType,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, CleanedTags, pt.Name
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CleanedTags,
        PostType,
        AnswerCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS PopularityRank
    FROM 
        RankedPosts
    WHERE 
        RankByDate = 1
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CleanedTags,
    tp.PostType,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.PopularityRank,
    CASE 
        WHEN tp.PopularityRank <= 10 THEN 'Hot Post'
        WHEN tp.PopularityRank <= 50 THEN 'Trending Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.PopularityRank
FETCH FIRST 100 ROWS ONLY;
