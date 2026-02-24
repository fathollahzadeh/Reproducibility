
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerDisplayName,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (
            SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId
        )
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.OwnerDisplayName, b.Class
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        OwnerDisplayName,
        BadgeCount,
        RANK() OVER (ORDER BY Score DESC) AS OverallRank
    FROM 
        PostWithBadges
    WHERE 
        BadgeCount > 0
),
RecentEdits AS (
    SELECT 
        p.Id AS PostId,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
        AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT ph.PostId) AS PostsEdited
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts p ON U.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    tp.Title,
    tp.Score,
    tp.OwnerDisplayName,
    tp.BadgeCount,
    ua.Upvotes,
    ua.Downvotes,
    ua.PostsEdited,
    COALESCE(recent.Editor, 'No Edits') AS LastEditor,
    COALESCE(CAST(recent.EditDate AS VARCHAR), 'N/A') AS LastEditDate,
    COALESCE(recent.Comment, 'No comments') AS EditComment
FROM 
    TopPosts tp
LEFT JOIN 
    RecentEdits recent ON tp.PostId = recent.PostId
LEFT JOIN 
    UserActivity ua ON tp.OwnerDisplayName = ua.DisplayName
WHERE 
    tp.OverallRank <= 10  
ORDER BY 
    tp.Score DESC, 
    tp.BadgeCount DESC;
