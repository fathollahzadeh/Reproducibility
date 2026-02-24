WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 5  
), PostAggregates AS (
    SELECT 
        f.Tags,
        COUNT(f.PostId) AS PostCount,
        SUM(f.UpvoteCount) AS TotalUpvotes,
        AVG(f.Score) AS AverageScore
    FROM 
        FilteredPosts f
    GROUP BY 
        f.Tags
), TagDetails AS (
    SELECT 
        CONCAT('<', t.TagName, '>') AS FormattedTagName,
        ta.PostCount,
        ta.TotalUpvotes,
        ta.AverageScore
    FROM 
        PostAggregates ta
    JOIN 
        Tags t ON t.TagName = ANY(string_to_array(ta.Tags, '>'))  
)
SELECT 
    td.FormattedTagName,
    td.PostCount,
    td.TotalUpvotes,
    td.AverageScore,
    (SELECT COUNT(*) FROM Users u WHERE u.Reputation > 1000) AS ActiveUsersWithHighReputation 
FROM 
    TagDetails td
ORDER BY 
    td.TotalUpvotes DESC;