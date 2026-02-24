WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND (p.Title IS NOT NULL OR p.Body IS NOT NULL)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class 
         FROM Badges 
         GROUP BY UserId) b ON u.Id = b.UserId
),
TopPosts AS (
    SELECT 
        rp.*,
        ur.Reputation,
        ur.BadgeClass
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank <= 5 
        AND ur.Reputation > 1000 
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.BadgeClass = 1 THEN 'Gold Badge Holder'
        WHEN tp.BadgeClass = 2 THEN 'Silver Badge Holder'
        WHEN tp.BadgeClass = 3 THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN tp.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Comments Available'
    END AS CommentStatus,
    CASE 
        WHEN tp.UpVoteCount - tp.DownVoteCount > 0 THEN 'Positive Reception'
        WHEN tp.UpVoteCount - tp.DownVoteCount < 0 THEN 'Negative Reception'
        ELSE 'Neutral Reception'
    END AS ReceptionStatus
FROM 
    TopPosts tp
WHERE 
    tp.Title LIKE '%SQL%'
ORDER BY 
    tp.CreationDate DESC;