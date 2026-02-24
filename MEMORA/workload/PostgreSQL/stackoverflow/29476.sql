
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.Tags IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagStatistics AS (
    SELECT 
        TRIM(unnest(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(u.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(u.DownVotes), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    ts.PostCount AS RelatedTagPostCount,
    ur.DisplayName AS UserName,
    ur.TotalBounty,
    ur.TotalUpVotes,
    ur.TotalDownVotes
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.TagName = ANY (string_to_array(rp.Tags, '>'))
JOIN 
    UserReputation ur ON rp.OwnerDisplayName = ur.DisplayName
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
