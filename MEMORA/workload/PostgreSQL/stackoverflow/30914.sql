
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
),
UserReputation AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
MergingTags AS (
    SELECT 
        t.Id,
        t.TagName,
        COUNT(po.Id) AS PostCount,
        STRING_AGG(po.Title, ', ') AS PostTitles
    FROM 
        Tags t
    LEFT JOIN 
        Posts po ON po.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
),
TopViewCounts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS TopRank
    FROM 
        Posts p
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostID,
    rp.Title,
    ur.DisplayName AS AuthorDisplayName,
    ur.Reputation AS AuthorReputation,
    ur.BadgeCount,
    rt.TagName,
    rt.PostCount,
    rt.PostTitles,
    COALESCE(cp.Comment, 'Not Closed') AS CloseComment,
    cp.CreationDate AS CloseDate
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserID = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostID)
LEFT JOIN 
    MergingTags rt ON rt.PostCount > 0 
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostID
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.PostID, ur.Reputation DESC;
