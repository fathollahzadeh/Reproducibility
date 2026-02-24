
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes, 
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, u.DisplayName, p.Title, p.Body, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.PostType,
        rp.OwnerDisplayName,
        rp.TotalComments,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  
),
PostPopularity AS (
    SELECT 
        fp.*,
        (fp.UpVotes - fp.DownVotes) AS PopularityScore
    FROM 
        FilteredPosts fp
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.CreationDate,
    pp.PostType,
    pp.TotalComments,
    pp.UpVotes,
    pp.DownVotes,
    pp.PopularityScore,
    CASE 
        WHEN pp.PopularityScore > 5 THEN 'High'
        WHEN pp.PopularityScore BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low' 
    END AS PopularityCategory
FROM 
    PostPopularity pp
ORDER BY 
    pp.PopularityScore DESC,
    pp.CreationDate DESC
LIMIT 10;
