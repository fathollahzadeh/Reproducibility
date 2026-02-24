
WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS RankScore 
    FROM 
        RecursivePostStats 
    WHERE 
        Score IS NOT NULL
),
TopUserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS BestBadgeClass 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        BestBadgeClass
    FROM 
        TopUserBadges
    WHERE 
        BadgeCount > 5 
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Comment,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRanking
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate AS QuestionDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    fu.DisplayName AS UserWithBadges,
    fu.BadgeCount,
    CASE 
        WHEN phs.EditRanking = 1 THEN 'Most Recent Edit'
        ELSE 'Earlier Edit'
    END AS EditStatus,
    phs.Comment AS EditComment
FROM 
    TopPosts tp
LEFT JOIN 
    Posts pp ON pp.Id = tp.PostId 
LEFT JOIN 
    FilteredUsers fu ON pp.OwnerUserId = fu.UserId
LEFT JOIN 
    PostHistoryStats phs ON tp.PostId = phs.PostId
WHERE 
    tp.RankScore <= 10 
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate ASC;
