WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.OwnerUserId IS NOT NULL
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 100
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title AS PopularPostTitle,
    rp.Score AS PopularPostScore,
    rp.ViewCount AS PopularPostViews,
    pt.TagName AS PopularTag,
    au.DisplayName AS ActiveUser,
    au.UpVotes AS UserUpVotes,
    au.DownVotes AS UserDownVotes
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.PostCount > 50
JOIN 
    ActiveUsers au ON au.UpVotes > 10
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, au.UpVotes DESC;