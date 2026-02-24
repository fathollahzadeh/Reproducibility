WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
TagsWithPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) as Rank
    FROM 
        TagsWithPostCounts
    WHERE 
        PostCount >= 3
),
RecentClosures AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        u.DisplayName AS ClosedBy
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
ClosedPostCounts AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS ClosedPostsCount
    FROM 
        RecentClosures rc
    JOIN 
        RankedPosts rp ON rc.PostId = rp.PostId
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(tp.PostId) AS TotalPosts,
    SUM(COALESCE(cpc.ClosedPostsCount, 0)) AS TotalClosedPosts,
    SUM(tp.CommentCount) AS TotalComments,
    SUM(tp.UpVoteCount) AS TotalUpVotes,
    SUM(tp.DownVoteCount) AS TotalDownVotes,
    STRING_AGG(tt.TagName, ', ') AS TopTags
FROM 
    Users u
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    ClosedPostCounts cpc ON u.Id = cpc.OwnerUserId
LEFT JOIN 
    TopTags tt ON tt.Rank <= 3 
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC
LIMIT 100;