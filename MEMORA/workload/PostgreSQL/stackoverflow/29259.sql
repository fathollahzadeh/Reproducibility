
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        U.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.Body, p.Tags, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Author,
        rp.TotalComments,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
),
TagStats AS (
    SELECT 
        UNNEST(string_to_array(rp.Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts rp
    GROUP BY 
        TagName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Author,
    fp.TotalComments,
    fp.UpVotes,
    fp.DownVotes,
    ts.TagName,
    ts.TagCount
FROM 
    FilteredPosts fp
JOIN 
    TagStats ts ON ts.TagName = ANY(string_to_array(fp.Tags, '>'))
ORDER BY 
    fp.UpVotes DESC, 
    fp.TotalComments DESC;
