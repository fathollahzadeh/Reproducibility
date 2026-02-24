
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        OwnerUserId, 
        OwnerDisplayName, 
        AnswerCount, 
        UpVotes, 
        DownVotes 
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount, 
        SUM(p.ViewCount) AS TotalViews, 
        SUM(p.AnswerCount) AS TotalAnswers 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId, 
    tp.Title AS PostTitle, 
    tp.CreationDate AS PostCreationDate, 
    tp.OwnerDisplayName AS PostOwner,
    us.DisplayName AS UserName, 
    us.BadgeCount AS UserBadgeCount, 
    us.TotalViews AS UserTotalViews, 
    us.TotalAnswers AS UserTotalAnswers, 
    tp.UpVotes, 
    tp.DownVotes, 
    tp.AnswerCount 
FROM 
    TopPosts tp
JOIN 
    UserStats us ON tp.OwnerUserId = us.UserId
ORDER BY 
    tp.UpVotes DESC, tp.CreationDate DESC
FETCH FIRST 10 ROWS WITH TIES;