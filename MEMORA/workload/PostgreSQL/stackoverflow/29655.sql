
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON t.TagName IS NOT NULL
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, pt.Name, p.CreationDate
),
TopPostAuthors AS (
    SELECT 
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.VoteCount) AS TotalVotes,
        STRING_AGG(DISTINCT rp.PostType, ', ') AS PostTypes,
        COUNT(rp.PostId) AS PostCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rnk <= 5  
    GROUP BY 
        rp.OwnerUserId, rp.OwnerDisplayName
)
SELECT 
    tpa.OwnerDisplayName,
    tpa.PostCount,
    tpa.TotalComments,
    tpa.TotalVotes,
    tpa.PostTypes,
    ARRAY_AGG(DISTINCT rp.Tags) AS AllTags
FROM 
    TopPostAuthors tpa
JOIN 
    RankedPosts rp ON tpa.OwnerUserId = rp.OwnerUserId
GROUP BY 
    tpa.OwnerDisplayName, tpa.PostCount, tpa.TotalComments, tpa.TotalVotes, tpa.PostTypes
ORDER BY 
    tpa.TotalVotes DESC, tpa.TotalComments DESC;
