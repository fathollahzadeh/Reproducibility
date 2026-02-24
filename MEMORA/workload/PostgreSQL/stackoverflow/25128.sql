WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithModerationHistory AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        COALESCE(ph.Comment, '') AS ModerationComment,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, ph.Comment
),
FinalResult AS (
    SELECT 
        fp.PostID,
        fp.Title,
        fp.Tags,
        fp.ViewCount,
        fp.Score,
        fp.AnswerCount,
        fp.CommentCount,
        ub.DisplayName AS UserDisplayName,
        ub.BadgeCount,
        pmh.ModerationComment,
        pmh.HistoryCount
    FROM 
        FilteredPosts fp
    JOIN 
        UsersWithBadges ub ON fp.PostID = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostID)
    LEFT JOIN 
        PostsWithModerationHistory pmh ON fp.PostID = pmh.PostID
)
SELECT 
    PostID,
    Title,
    Tags,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    UserDisplayName,
    BadgeCount,
    ModerationComment,
    HistoryCount
FROM 
    FinalResult
ORDER BY 
    Score DESC, ViewCount DESC;