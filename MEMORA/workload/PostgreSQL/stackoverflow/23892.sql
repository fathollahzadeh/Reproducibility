
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.AcceptedAnswerId
),

PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),

ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        pt.Name AS PostHistoryTypeName
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rt.TagName AS PopularTag,
    ub.UserId,
    ub.TotalBadges,
    ub.MaxBadgeClass,
    cp.PostId AS ClosedPostId,
    cp.Title AS ClosedPostTitle,
    cp.CreationDate AS ClosedPostDate,
    cp.PostHistoryTypeName
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags rt ON rp.Title ILIKE '%' || rt.TagName || '%'
LEFT JOIN 
    UserBadges ub ON rp.AcceptedAnswerId = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RN <= 3
    AND (rp.UpVotes - rp.DownVotes) > 10
ORDER BY 
    rp.CreationDate DESC, 
    rp.UpVotes DESC NULLS LAST;
