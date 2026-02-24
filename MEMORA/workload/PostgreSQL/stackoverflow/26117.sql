
WITH RankedPosts AS (
   SELECT 
       p.Id AS PostId,
       p.Title,
       p.Body,
       p.Tags,
       COUNT(c.Id) AS CommentCount,
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
       DENSE_RANK() OVER (ORDER BY COUNT(c.Id) DESC, COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
   FROM 
       Posts p
   LEFT JOIN 
       Comments c ON p.Id = c.PostId
   LEFT JOIN 
       Votes v ON p.Id = v.PostId
   WHERE 
       p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year' 
       AND p.PostTypeId = 1  
   GROUP BY 
       p.Id, p.Title, p.Body, p.Tags
), FilteredPosts AS (
   SELECT 
       rp.PostId,
       rp.Title,
       rp.Body,
       rp.Tags,
       rp.CommentCount,
       rp.UpVoteCount,
       rp.DownVoteCount,
       rp.Rank,
       ROW_NUMBER() OVER (PARTITION BY CASE 
           WHEN rp.Tags LIKE '%sql%' THEN 'SQL'
           WHEN rp.Tags LIKE '%database%' THEN 'Database'
           ELSE 'Other' END 
           ORDER BY rp.Rank) AS TagGroupRank
   FROM 
       RankedPosts rp
)
SELECT 
   fp.PostId,
   fp.Title,
   fp.Body,
   fp.Tags,
   fp.CommentCount,
   fp.UpVoteCount,
   fp.DownVoteCount,
   CASE 
       WHEN fp.TagGroupRank <= 5 THEN 'Top 5'
       WHEN fp.TagGroupRank <= 15 THEN 'Next 10'
       ELSE 'Below Top 15'
   END AS PostRankCategory
FROM 
   FilteredPosts fp
WHERE 
   fp.TagGroupRank <= 15
ORDER BY 
   fp.Rank, fp.TagGroupRank;
